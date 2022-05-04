function getLinearElasticityGradient_test(grid2D_name, ...
    def2D_name, grid3D_name, def3D_name, output_path)
%%
grid_name = {grid2D_name, grid3D_name};
defField_name = {def2D_name, def3D_name};

for i=1:2
    %Read the grid image
    grid_image = load_untouch_nii(grid_name{i});
    grid_data = grid_image.img;
    orientation = zeros(3,3);
    orientation(1:3,1) = grid_image.hdr.hist.srow_x(1:3);
    orientation(1:3,2) = grid_image.hdr.hist.srow_y(1:3);
    orientation(1:3,3) = grid_image.hdr.hist.srow_z(1:3);
    orientation = inv(orientation);
    grid_dim=[grid_image.hdr.dime.dim(2), ...
        grid_image.hdr.dime.dim(3), ...
        grid_image.hdr.dime.dim(4) ...
        ];

    grad_data = zeros(size(grid_data));

    % Precompute the basis values
    basis = getBSplineCoefficient(0);
    first = getBSplineCoefficientFirstOrder(0);
    % Compute the value at the control point position only
    for x=2:grid_dim(1)-1
        for y=2:grid_dim(2)-1
            if (i+1)==2
                jacobian = zeros(2,2);
                for a=1:3
                    for b=1:3
                        jacobian(1,1)=jacobian(1,1) + ...
                            first(a) * basis(b) * ...
                            grid_data(x+a-2, y+b-2, 1, 1, 1);
                        jacobian(1,2)=jacobian(1,2) + ...
                            basis(a) * first(b) * ...
                            grid_data(x+a-2, y+b-2, 1, 1, 1);
                        jacobian(2,1)=jacobian(2,1) + ...
                            first(a) * basis(b) * ...
                            grid_data(x+a-2, y+b-2, 1, 1, 2);
                        jacobian(2,2)=jacobian(2,2) + ...
                            basis(a) * first(b) * ...
                            grid_data(x+a-2, y+b-2, 1, 1, 2);
                    end
                end
                jacobian = orientation(1:2,1:2) * jacobian';
                rotation = polarDecomposition(jacobian);
                jacobian = (rotation) \ jacobian;
                jacobian = jacobian - eye(2);
                for a=1:3
                    for b=1:3
                        if x+a-2<=grid_dim(1) && x+a-2>0 && ...
                           y+b-2<=grid_dim(2) && y+b-2>0
                            gradient(1) = - 2 * jacobian(1,1) * ...
                                first(-a+4) * basis(-b+4);
                            gradient(2) = - 2 * jacobian(2,2) * ...
                                basis(-a+4) * first(-b+4);
                            grad_data(x+a-2,y+b-2,1,1,1:2) = ...
                                squeeze(grad_data(x+a-2,y+b-2,1,1,1:2)) + ...
                                orientation(1:2,1:2) \ ...
                                [gradient(1), gradient(2)]' ...
                                ./ prod(grid_dim);
                        end
                    end
                end
            else
                for z=2:grid_dim(3)-1
                    jacobian = zeros(3,3);
                    for a=1:3
                        for b=1:3
                            for c=1:3
                                jacobian(1,1)=jacobian(1,1) +  ...
                                    first(a) * basis(b) * basis(c) * ...
                                    grid_data(x+a-2, y+b-2, z+c-2, 1, 1);
                                jacobian(1,2)=jacobian(1,2) +  ...
                                    basis(a) * first(b) * basis(c) * ...
                                    grid_data(x+a-2, y+b-2, z+c-2, 1, 1);
                                jacobian(1,3)=jacobian(1,3) +  ...
                                    basis(a) * basis(b) * first(c) * ...
                                    grid_data(x+a-2, y+b-2, z+c-2, 1, 1);

                                jacobian(2,1)=jacobian(2,1) +  ...
                                    first(a) * basis(b) * basis(c) * ...
                                    grid_data(x+a-2, y+b-2, z+c-2, 1, 2);
                                jacobian(2,2)=jacobian(2,2) +  ...
                                    basis(a) * first(b) * basis(c) * ...
                                    grid_data(x+a-2, y+b-2, z+c-2, 1, 2);
                                jacobian(2,3)=jacobian(2,3) +  ...
                                    basis(a) * basis(b) * first(c) * ...
                                    grid_data(x+a-2, y+b-2, z+c-2, 1, 2);

                                jacobian(3,1)=jacobian(3,1) +  ...
                                    first(a) * basis(b) * basis(c) * ...
                                    grid_data(x+a-2, y+b-2, z+c-2, 1, 3);
                                jacobian(3,2)=jacobian(3,2) +  ...
                                    basis(a) * first(b) * basis(c) * ...
                                    grid_data(x+a-2, y+b-2, z+c-2, 1, 3);
                                jacobian(3,3)=jacobian(3,3) +  ...
                                    basis(a) * basis(b) * first(c) * ...
                                    grid_data(x+a-2, y+b-2, z+c-2, 1, 3);
                            end
                        end
                    end
                    jacobian = orientation(:,:) * jacobian';
                    rotation = polarDecomposition(jacobian);
                    jacobian = (rotation) \ jacobian;
                    jacobian = jacobian - eye(3);
                    for a=1:3
                        for b=1:3
                            for c=1:3
                                if x+a-2<=grid_dim(1) && x+a-2>0 && ...
                                   y+b-2<=grid_dim(2) && y+b-2>0 && ...
                                   z+c-2<=grid_dim(3) && z+c-2>0
                                    gradient(1) = - 2 * ...
                                        jacobian(1,1) * first(-a+4) * basis(-b+4) * basis(-c+4);
                                    gradient(2) = - 2 * ...
                                        jacobian(2,2) * basis(-a+4) * first(-b+4) * basis(-c+4);
                                    gradient(3) = - 2 * ...
                                        jacobian(3,3) * basis(-a+4) * basis(-b+4) * first(-c+4);
                                    grad_data(x+a-2,y+b-2,z+c-2,1,1:3) = ...
                                        squeeze(grad_data(x+a-2,y+b-2,z+c-2,1,1:3)) + ...
                                        orientation \ ...
                                        [gradient(1), gradient(2), gradient(3)]' ...
                                        ./ prod(grid_dim);
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    clear basis first
    % Save the control point gradient
    gradField_nii=make_nii(grad_data,...
        [grid_image.hdr.dime.pixdim(2),...
         grid_image.hdr.dime.pixdim(3),...
         grid_image.hdr.dime.pixdim(4)],...
        [], ...
        16 ...
        );
    gradField_nii.hdr.dime.pixdim(1)=grid_image.hdr.dime.pixdim(1);
    gradField_nii.hdr.hist.quatern_b=grid_image.hdr.hist.quatern_b;
    gradField_nii.hdr.hist.quatern_c=grid_image.hdr.hist.quatern_c;
    gradField_nii.hdr.hist.quatern_d=grid_image.hdr.hist.quatern_d;
    gradField_nii.hdr.hist.qoffset_x=grid_image.hdr.hist.qoffset_x;
    gradField_nii.hdr.hist.qoffset_y=grid_image.hdr.hist.qoffset_y;
    gradField_nii.hdr.hist.qoffset_z=grid_image.hdr.hist.qoffset_z;
    gradField_nii.hdr.hist=grid_image.hdr.hist;
    gradField_nii.hdr.hist.srow_x=grid_image.hdr.hist.srow_x;
    gradField_nii.hdr.hist.srow_y=grid_image.hdr.hist.srow_y;
    gradField_nii.hdr.hist.srow_z=grid_image.hdr.hist.srow_z;
    filename_nii=[output_path,'/le_grad_spline_approx', ...
        int2str(i+1), 'D.nii.gz'];
    save_nii(gradField_nii, filename_nii);
    fprintf('%s has been saved\n', filename_nii);

    % Read the def image
    def_image = load_untouch_nii(defField_name{i});
    def_dim=[def_image.hdr.dime.dim(2), ...
        def_image.hdr.dime.dim(3), ...
        def_image.hdr.dime.dim(4) ...
        ];
    spacing = grid_image.hdr.dime.pixdim(2) / def_image.hdr.dime.pixdim(2);
    % reset to gradient data
    grad_data = zeros(size(grid_data));
    % Compute the value from all voxel position
    for x=0:def_dim(1)-1
         pre_x = floor(x/spacing);
         norm_x = x/spacing - pre_x;
         basis_x = getBSplineCoefficient(norm_x);
         first_x = getBSplineCoefficientFirstOrder(norm_x);
         for y=0:def_dim(2)-1
             pre_y = floor(y/spacing);
             norm_y = y/spacing - pre_y;
             basis_y = getBSplineCoefficient(norm_y);
             first_y = getBSplineCoefficientFirstOrder(norm_y);
             if (i+1)==2
                 jacobian = zeros(2,2);
                 for a=1:4
                     for b=1:4
                         jacobian(1,1)=jacobian(1,1) + ...
                             first_x(a) * basis_y(b) * ...
                             grid_data(pre_x+a, pre_y+b, 1, 1, 1);
                         jacobian(1,2)=jacobian(1,2) + ...
                             basis_x(a) * first_y(b) * ...
                             grid_data(pre_x+a, pre_y+b, 1, 1, 1);
                         jacobian(2,1)=jacobian(2,1) + ...
                             first_x(a) * basis_y(b) * ...
                             grid_data(pre_x+a, pre_y+b, 1, 1, 2);
                         jacobian(2,2)=jacobian(2,2) + ...
                             basis_x(a) * first_y(b) * ...
                             grid_data(pre_x+a, pre_y+b, 1, 1, 2);
                     end
                 end
                 jacobian = orientation(1:2,1:2) * jacobian';
                 rotation = polarDecomposition(jacobian);
                 jacobian = (rotation) \ jacobian;
                 jacobian = jacobian - eye(2);
                 for b=1:4
                     for a=1:4
                         gradient(1) = - 2 * jacobian(1,1) * ...
                             first_x(-a+5) * basis_y(-b+5);
                         gradient(2) = - 2 * jacobian(2,2) * ...
                             basis_x(-a+5) * first_y(-b+5);
                         grad_data(pre_x+a,pre_y+b,1,1,1:2) = ...
                             squeeze(grad_data(pre_x+a,pre_y+b,1,1,1:2)) + ...
                             orientation(1:2,1:2) \ ...
                             [gradient(1), gradient(2)]' ...
                             ./ prod(def_dim);
                     end
                 end
             else
                 for z=0:def_dim(3)-1
                     pre_z = floor(z/spacing);
                     norm_z = z/spacing - pre_z;
                     basis_z = getBSplineCoefficient(norm_z);
                     first_z = getBSplineCoefficientFirstOrder(norm_z);
                     jacobian = zeros(3,3);
                     for a=1:4
                         for b=1:4
                             for c=1:4
                                 jacobian(1,1)=jacobian(1,1) +  ...
                                     first_x(a) * basis_y(b) * basis_z(c) * ...
                                     grid_data(pre_x+a, pre_y+b, pre_z+c, 1, 1);
                                 jacobian(1,2)=jacobian(1,2) +  ...
                                     basis_x(a) * first_y(b) * basis_z(c) * ...
                                     grid_data(pre_x+a, pre_y+b, pre_z+c, 1, 1);
                                 jacobian(1,3)=jacobian(1,3) +  ...
                                     basis_x(a) * basis_y(b) * first_z(c) * ...
                                     grid_data(pre_x+a, pre_y+b, pre_z+c, 1, 1);

                                 jacobian(2,1)=jacobian(2,1) +  ...
                                     first_x(a) * basis_y(b) * basis_z(c) * ...
                                     grid_data(pre_x+a, pre_y+b, pre_z+c, 1, 2);
                                 jacobian(2,2)=jacobian(2,2) +  ...
                                     basis_x(a) * first_y(b) * basis_z(c) * ...
                                     grid_data(pre_x+a, pre_y+b, pre_z+c, 1, 2);
                                 jacobian(2,3)=jacobian(2,3) +  ...
                                     basis_x(a) * basis_y(b) * first_z(c) * ...
                                     grid_data(pre_x+a, pre_y+b, pre_z+c, 1, 2);

                                 jacobian(3,1)=jacobian(3,1) +  ...
                                     first_x(a) * basis_y(b) * basis_z(c) * ...
                                     grid_data(pre_x+a, pre_y+b, pre_z+c, 1, 3);
                                 jacobian(3,2)=jacobian(3,2) +  ...
                                     basis_x(a) * first_y(b) * basis_z(c) * ...
                                     grid_data(pre_x+a, pre_y+b, pre_z+c, 1, 3);
                                 jacobian(3,3)=jacobian(3,3) +  ...
                                     basis_x(a) * basis_y(b) * first_z(c) * ...
                                     grid_data(pre_x+a, pre_y+b, pre_z+c, 1, 3);
                             end
                         end
                     end
                     jacobian = orientation(:,:) * jacobian';
                     rotation = polarDecomposition(jacobian);
                     jacobian = (rotation) \ jacobian;
                     jacobian = jacobian - eye(3);
                     for a=1:4
                         for b=1:4
                             for c=1:4
                                 gradient(1) = - 2 * ...
                                     jacobian(1,1) * ...
                                     first_x(-a+5) * basis_y(-b+5) * basis_z(-c+5);
                                 gradient(2) = - 2 * ...
                                     jacobian(2,2) * ...
                                     basis_x(-a+5) * first_y(-b+5) * basis_z(-c+5);
                                 gradient(3) = - 2 * ...
                                     jacobian(3,3) * ...
                                     basis_x(-a+5) * basis_y(-b+5) * first_z(-c+5);
                                 grad_data(pre_x+a,pre_y+b,pre_z+c,1,1:3) = ...
                                     squeeze(grad_data(pre_x+a,pre_y+b,pre_z+c,1,1:3)) + ...
                                     orientation \ ...
                                     [gradient(1), gradient(2), gradient(3)]' ...
                                     ./ prod(def_dim);
                             end
                         end
                     end
                 end
             end
         end
     end
     % Save the control point gradient
     clear gradField_nii
     gradField_nii=make_nii(grad_data,...
         [grid_image.hdr.dime.pixdim(2),...
          grid_image.hdr.dime.pixdim(3),...
          grid_image.hdr.dime.pixdim(4)],...
         [], ...
         16 ...
         );
     gradField_nii.hdr.dime.pixdim(1)=grid_image.hdr.dime.pixdim(1);
     gradField_nii.hdr.hist.quatern_b=grid_image.hdr.hist.quatern_b;
     gradField_nii.hdr.hist.quatern_c=grid_image.hdr.hist.quatern_c;
     gradField_nii.hdr.hist.quatern_d=grid_image.hdr.hist.quatern_d;
     gradField_nii.hdr.hist.qoffset_x=grid_image.hdr.hist.qoffset_x;
     gradField_nii.hdr.hist.qoffset_y=grid_image.hdr.hist.qoffset_y;
     gradField_nii.hdr.hist.qoffset_z=grid_image.hdr.hist.qoffset_z;
     gradField_nii.hdr.hist=grid_image.hdr.hist;
     gradField_nii.hdr.hist.srow_x=grid_image.hdr.hist.srow_x;
     gradField_nii.hdr.hist.srow_y=grid_image.hdr.hist.srow_y;
     gradField_nii.hdr.hist.srow_z=grid_image.hdr.hist.srow_z;
     filename_nii=[output_path,'/le_grad_spline_dense', ...
         int2str(i+1), 'D.nii.gz'];
     save_nii(gradField_nii, filename_nii);
     fprintf('%s has been saved\n', filename_nii);
     clear grid_image;

    % Gradient from deformation field
    def_data = def_image.img;
    grad_data = zeros(size(def_data));
    orientation(1:3,1) = def_image.hdr.hist.srow_x(1:3);
    orientation(1:3,2) = def_image.hdr.hist.srow_y(1:3);
    orientation(1:3,3) = def_image.hdr.hist.srow_z(1:3);
    orientation = inv(orientation);
    basis=[1,0];
    first=[-1,1];
    for x=1:def_dim(1)
        if x==def_dim(1)
            X=x-1;
        else
            X=x;
        end
        for y=1:def_dim(2)
            if y==def_dim(2)
                Y=y-1;
            else
                Y=y;
            end
            if (i+1)==2
                jacobian = zeros(2,2);
                for a=1:2
                    for b=1:2
                        jacobian(1,1)=jacobian(1,1) + ...
                            first(a) * basis(b) * ...
                            def_data(X+a-1, Y+b-1, 1, 1, 1);
                        jacobian(1,2)=jacobian(1,2) + ...
                            basis(a) * first(b) * ...
                            def_data(X+a-1, Y+b-1, 1, 1, 1);
                        jacobian(2,1)=jacobian(2,1) + ...
                            first(a) * basis(b) * ...
                            def_data(X+a-1, Y+b-1, 1, 1, 2);
                        jacobian(2,2)=jacobian(2,2) + ...
                            basis(a) * first(b) * ...
                            def_data(X+a-1, Y+b-1, 1, 1, 2);
                    end
                end
                jacobian = orientation(1:2,1:2) * jacobian';
                rotation = polarDecomposition(jacobian);
                jacobian = (rotation) \ jacobian;
                jacobian = jacobian - eye(2);
                for b=1:2
                    for a=1:2
                        gradient(1) = - 2 * jacobian(1,1) * ...
                            first(-a+3) * basis(-b+3);
                        gradient(2) = - 2 * jacobian(2,2) * ...
                            basis(-a+3) * first(-b+3);
                        grad_data(X+a-1,Y+b-1,1,1,1:2) = ...
                            squeeze(grad_data(X+a-1,Y+b-1,1,1,1:2)) + ...
                            orientation(1:2,1:2) \ ...
                            [gradient(1), gradient(2)]' ...
                            ./ prod(def_dim);
                    end
                end
            else
                for z=1:def_dim(3)
                    if z==def_dim(3)
                        Z=z-1;
                    else
                        Z=z;
                    end
                    jacobian = zeros(3,3);
                    for a=1:2
                        for b=1:2
                            for c=1:2
                                jacobian(1,1)=jacobian(1,1) + ...
                                    first(a) * basis(b) * basis(c) * ...
                                    def_data(X+a-1, Y+b-1, Z+c-1, 1, 1);
                                jacobian(1,2)=jacobian(1,2) + ...
                                    basis(a) * first(b) * basis(c) * ...
                                    def_data(X+a-1, Y+b-1, Z+c-1, 1, 1);
                                jacobian(1,3)=jacobian(1,3) + ...
                                    basis(a) * basis(b) * first(c) * ...
                                    def_data(X+a-1, Y+b-1, Z+c-1, 1, 1);

                                jacobian(2,1)=jacobian(2,1) + ...
                                    first(a) * basis(b) * basis(c) * ...
                                    def_data(X+a-1, Y+b-1, Z+c-1, 1, 2);
                                jacobian(2,2)=jacobian(2,2) + ...
                                    basis(a) * first(b) * basis(c) * ...
                                    def_data(X+a-1, Y+b-1, Z+c-1, 1, 2);
                                jacobian(2,3)=jacobian(2,3) + ...
                                    basis(a) * basis(b) * first(c) * ...
                                    def_data(X+a-1, Y+b-1, Z+c-1, 1, 2);

                                jacobian(3,1)=jacobian(3,1) + ...
                                    first(a) * basis(b) * basis(c) * ...
                                    def_data(X+a-1, Y+b-1, Z+c-1, 1, 3);
                                jacobian(3,2)=jacobian(3,2) + ...
                                    basis(a) * first(b) * basis(c) * ...
                                    def_data(X+a-1, Y+b-1, Z+c-1, 1, 3);
                                jacobian(3,3)=jacobian(3,3) + ...
                                    basis(a) * basis(b) * first(c) * ...
                                    def_data(X+a-1, Y+b-1, Z+c-1, 1, 3);
                            end
                        end
                    end
                    jacobian = orientation(:,:) * jacobian';
                    rotation = polarDecomposition(jacobian);
                    jacobian = (rotation) \ jacobian;
                    jacobian = jacobian - eye(3);
                    for a=1:2
                        for b=1:2
                            for c=1:2
                                gradient(1) = - 2 * ...
                                    jacobian(1,1) * ...
                                    first(-a+3) * basis(-b+3) * basis(-c+3);
                                gradient(2) = - 2 * ...
                                    jacobian(2,2) * ...
                                    basis(-a+3) * first(-b+3) * basis(-c+3);
                                gradient(3) = - 2 * ...
                                    jacobian(3,3) * ...
                                    basis(-a+3) * basis(-b+3) * first(-c+3);
                                grad_data(X+a-1,Y+b-1,Z+c-1,1,1:3) = ...
                                    squeeze(grad_data(X+a-1,Y+b-1,Z+c-1,1,1:3)) + ...
                                    orientation \ ...
                                    [gradient(1), gradient(2), gradient(3)]' ...
                                    ./ prod(def_dim);
                            end
                        end
                    end
                end
            end
        end
    end
    clear gradField_nii
    gradField_nii=make_nii(grad_data,...
        [def_image.hdr.dime.pixdim(2),...
         def_image.hdr.dime.pixdim(3),...
         def_image.hdr.dime.pixdim(4)],...
        [], ...
        16 ...
        );
    gradField_nii.hdr.dime.pixdim(1)=def_image.hdr.dime.pixdim(1);
    gradField_nii.hdr.hist.quatern_b=def_image.hdr.hist.quatern_b;
    gradField_nii.hdr.hist.quatern_c=def_image.hdr.hist.quatern_c;
    gradField_nii.hdr.hist.quatern_d=def_image.hdr.hist.quatern_d;
    gradField_nii.hdr.hist.qoffset_x=def_image.hdr.hist.qoffset_x;
    gradField_nii.hdr.hist.qoffset_y=def_image.hdr.hist.qoffset_y;
    gradField_nii.hdr.hist.qoffset_z=def_image.hdr.hist.qoffset_z;
    gradField_nii.hdr.hist=def_image.hdr.hist;
    gradField_nii.hdr.hist.srow_x=def_image.hdr.hist.srow_x;
    gradField_nii.hdr.hist.srow_y=def_image.hdr.hist.srow_y;
    gradField_nii.hdr.hist.srow_z=def_image.hdr.hist.srow_z;
    filename_nii=[output_path,'/le_grad_field_dense', ...
        int2str(i+1), 'D.nii.gz'];
    save_nii(gradField_nii, filename_nii);
    fprintf('%s has been saved\n', filename_nii);
end

return

function R = polarDecomposition(F)
%% Polar decomposition of a given matrix
C = F'*F;
[Q0, lambdasquare] = eig(C);
lambda = sqrt(diag((lambdasquare)));
Uinv = repmat(1./lambda',size(F,1),1).*Q0*Q0';
R = F*Uinv;

function basis = getBSplineCoefficient(dist)
%% Given a normalise position return the 4 corresponding basis values
basis(1) = (1-dist)*(1-dist)*(1-dist)/6;
basis(2) = (3*dist*dist*dist - 6*dist*dist + 4)/6.0;
basis(3) = (-3*dist*dist*dist + 3*dist*dist + 3*dist + 1)/6;
basis(4) = dist*dist*dist/6;

function first = getBSplineCoefficientFirstOrder(dist)
%% Given a normalise position return the 4 corresponding basis values
first(4)= dist * dist / 2;
first(1)= dist - 0.5 - first(4);
first(3)= 1 + first(1) - 2*first(4);
first(2)= - first(1) - first(3) - first(4);

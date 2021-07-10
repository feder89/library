import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { StudentsForClassComponent } from './students-for-class.component';

describe('StudentsForClassComponent', () => {
  let component: StudentsForClassComponent;
  let fixture: ComponentFixture<StudentsForClassComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ StudentsForClassComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(StudentsForClassComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
